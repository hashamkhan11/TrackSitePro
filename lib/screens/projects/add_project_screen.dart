// ignore_for_file: unnecessary_cast

import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

// ── Design tokens (mirrors dashboard) ────────────────────────────────────────
class AppColors {
  static const primaryBlue   = Color(0xFF2563EB);
  static const lightBlue     = Color(0xFFEFF6FF);
  static const mediumBlue    = Color(0xFFBFDBFE);
  static const darkBlue      = Color(0xFF1E40AF);
  static const successGreen  = Color(0xFF10B981);
  static const lightGreen    = Color(0xFFECFDF5);
  static const warningOrange = Color(0xFFF59E0B);
  static const lightOrange   = Color(0xFFFEF3C7);
  static const lightGray     = Color(0xFFF9FAFB);
  static const borderGray    = Color(0xFFE5E7EB);
  static const textPrimary   = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary  = Color(0xFF9CA3AF);
  static const expiredRed    = Color(0xFFEF4444);
}

// ── Shared input decoration factory ──────────────────────────────────────────
InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
  Color? iconColor,
  Widget? suffix,
  bool isRequired = false,
}) {
  final color = iconColor ?? AppColors.primaryBlue;
  return InputDecoration(
    labelText: isRequired ? '$label *' : label,
    labelStyle: const TextStyle(
        fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
    floatingLabelStyle: const TextStyle(
        fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
    prefixIcon: Icon(icon, size: 18, color: color.withOpacity(0.75)),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderGray)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderGray)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.expiredRed)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.expiredRed, width: 2)),
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────
class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});
  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final _dateController            = TextEditingController();
  final _tenderEnquiryController   = TextEditingController();
  final _jobNoController           = TextEditingController();
  final _workOrderNoController     = TextEditingController();
  final _jobDescriptionController  = TextEditingController();
  final _taxRateController         = TextEditingController();
  final _totalExcludingTaxController = TextEditingController();
  final _taxAmountController       = TextEditingController();
  final _totalAmountController     = TextEditingController();

  DateTime? projectDate;
  double taxRate = 16.0, taxAmount = 0, totalExcludingTax = 0, totalAmount = 0;

  bool isLoading = false;
  bool isExtractingFromImage = false;
  String? firmId;
  // Supervisor assignment
  List<Map<String, dynamic>> _supervisors = [];
  String? _selectedSupervisorId;
  String? _selectedSupervisorName;
  String? _selectedSupervisorEmail;
  bool _loadingSupervisors = false;

  // Work order image captured for AI extraction – stored to project documents
  Uint8List? _workOrderBytes;
  String? _workOrderFileName;

  // Supplied at build time with --dart-define=GEMINI_API_KEY=... — never hardcode
  // a real key here, this file is public. Falls back to OCR when unset.
  final String geminiApiKey = const String.fromEnvironment('GEMINI_API_KEY');
  DateTime? _lastApiCallTime;
  static const int _minSecondsBetweenCalls = 10;
  String? _workingModel;
  bool _useOCR = false;

  // ── lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadFirmDetails();
    taxRate = 16.0;
    _taxRateController.text = taxRate.toString();
    _totalExcludingTaxController.text = '0';
    _taxAmountController.text = '0';
    _totalAmountController.text = '0';

    _totalExcludingTaxController.addListener(_updateFromExcludingTax);
    _taxAmountController.addListener(_updateFromTaxAmount);
    _totalAmountController.addListener(_updateFromTotalAmount);
    _taxRateController.addListener(_updateFromTaxRate);

    WidgetsBinding.instance.addPostFrameCallback((_) => _testGeminiModels());
  }

  @override
  void dispose() {
    for (final c in [
      _dateController, _tenderEnquiryController, _jobNoController,
      _workOrderNoController, _jobDescriptionController, _taxRateController,
      _totalExcludingTaxController, _taxAmountController, _totalAmountController,
    ]) { c.dispose(); }
    super.dispose();
  }

  // ── tax calculations (unchanged logic) ─────────────────────────────────────

  void _updateFromExcludingTax() {
    final net  = double.tryParse(_totalExcludingTaxController.text) ?? 0;
    final rate = double.tryParse(_taxRateController.text) ?? 0;
    setState(() {
      totalExcludingTax = net; taxRate = rate;
      taxAmount  = net * (rate / 100);
      totalAmount = net + taxAmount;
      _setWithoutListener(_taxAmountController,   _updateFromTaxAmount,    taxAmount.toStringAsFixed(2));
      _setWithoutListener(_totalAmountController, _updateFromTotalAmount,  totalAmount.toStringAsFixed(2));
    });
  }

  void _updateFromTaxAmount() {
    final tax  = double.tryParse(_taxAmountController.text) ?? 0;
    final rate = double.tryParse(_taxRateController.text) ?? 0;
    setState(() {
      taxAmount = tax; taxRate = rate;
      if (rate > 0) totalExcludingTax = tax / (rate / 100);
      totalAmount = totalExcludingTax + tax;
      _setWithoutListener(_totalExcludingTaxController, _updateFromExcludingTax, totalExcludingTax.toStringAsFixed(2));
      _setWithoutListener(_totalAmountController,       _updateFromTotalAmount,  totalAmount.toStringAsFixed(2));
    });
  }

  void _updateFromTotalAmount() {
    final tot  = double.tryParse(_totalAmountController.text) ?? 0;
    final rate = double.tryParse(_taxRateController.text) ?? 0;
    setState(() {
      totalAmount = tot; taxRate = rate;
      if (rate > 0) {
        totalExcludingTax = tot / (1 + rate / 100);
        taxAmount = tot - totalExcludingTax;
      }
      _setWithoutListener(_totalExcludingTaxController, _updateFromExcludingTax, totalExcludingTax.toStringAsFixed(2));
      _setWithoutListener(_taxAmountController,         _updateFromTaxAmount,    taxAmount.toStringAsFixed(2));
    });
  }

  void _updateFromTaxRate() {
    final rate = double.tryParse(_taxRateController.text) ?? 0;
    setState(() {
      taxRate = rate;
      taxAmount  = totalExcludingTax * (rate / 100);
      totalAmount = totalExcludingTax + taxAmount;
      _setWithoutListener(_taxAmountController,   _updateFromTaxAmount,   taxAmount.toStringAsFixed(2));
      _setWithoutListener(_totalAmountController, _updateFromTotalAmount, totalAmount.toStringAsFixed(2));
    });
  }

  void _setWithoutListener(TextEditingController c, VoidCallback listener, String value) {
    c.removeListener(listener);
    c.text = value;
    c.addListener(listener);
  }

  // ── AI helpers (logic unchanged) ───────────────────────────────────────────

  Future<void> _testGeminiModels() async {
    if (geminiApiKey.isEmpty) {
      setState(() { _workingModel = null; _useOCR = true; });
      return;
    }
    for (final model in ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-1.5-flash']) {
      try {
        final r = await http.post(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$geminiApiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'contents': [{'parts': [{'text': 'Respond with ONLY this JSON: {"status": "ok"}'}]}],
              'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 100}}),
        ).timeout(const Duration(seconds: 5));
        if (r.statusCode == 200) {
          final txt = jsonDecode(r.body)['candidates'][0]['content']['parts'][0]['text'];
          final j = _extractJson(txt);
          if (j != null) { jsonDecode(j); setState(() { _workingModel = model; _useOCR = false; }); return; }
        }
      } catch (_) {}
    }
    setState(() { _workingModel = null; _useOCR = true; });
  }

  String? _extractJson(String text) {
    text = text.replaceAll('```json', '').replaceAll('```', '').trim();
    final s = text.indexOf('{'), e = text.lastIndexOf('}') + 1;
    if (s >= 0 && e > s) return text.substring(s, e);
    final as2 = text.indexOf('['), ae = text.lastIndexOf(']') + 1;
    if (as2 >= 0 && ae > as2) return text.substring(as2, ae);
    return null;
  }

  Future<void> _loadFirmDetails() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get()
          .timeout(const Duration(seconds: 10));
      setState(() {
        firmId = (doc.data() as Map<String, dynamic>?)?['assignedFirmId'] ?? doc.data()?['firmId'];
      });
      if (firmId != null) {
        await _loadSupervisorsForFirm(firmId!);
      }
    } catch (e) {
      _snack('Error loading firm: $e', error: true);
    }
  }

  Future<void> _loadSupervisorsForFirm(String firmId) async {
    setState(() {
      _loadingSupervisors = true;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('firms')
          .doc(firmId)
          .collection('supervisors')
          .orderBy('name')
          .get()
          .timeout(const Duration(seconds: 10));

      final items = snap.docs
          .map((d) => {
                'id': d.id,
                'name': d.data()['name'] ?? '',
                'email': d.data()['email'] ?? '',
              })
          .toList();
      setState(() {
        _supervisors = items;
      });
    } catch (e) {
      _snack('Error loading supervisors: $e', error: true);
    } finally {
      if (mounted) {
        setState(() {
          _loadingSupervisors = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023), lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryBlue, onPrimary: Colors.white,
            surface: Colors.white, onSurface: AppColors.textPrimary),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() {
      _dateController.text = DateFormat('dd-MMM-yyyy').format(picked);
      projectDate = picked;
    });
  }

  Future<void> _extractFromImage() async {
    if (_useOCR) { await _extractWithOCRspace(); return; }
    if (_workingModel != null) { await _extractWithGemini(); return; }
    _snack('AI is initializing, please wait…');
  }

  bool _checkRateLimit() {
    if (_lastApiCallTime != null) {
      final diff = DateTime.now().difference(_lastApiCallTime!).inSeconds;
      if (diff < _minSecondsBetweenCalls) {
        _snack('Please wait ${_minSecondsBetweenCalls - diff}s before retrying');
        return false;
      }
    }
    return true;
  }

  Future<void> _extractWithGemini() async {
    if (!_checkRateLimit()) return;
    Uint8List? bytes;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) { 
        _snack('No image selected'); 
        return; 
      }
      bytes = await image.readAsBytes();
      
      setState(() => isExtractingFromImage = true);
      _lastApiCallTime = DateTime.now();

      const prompt = '''
You are checking if an image is a CONSTRUCTION WORK ORDER for a building/civil project.

1. First decide:
   - isWorkOrder: true ONLY if this looks like a formal work order / contract / job award / tender acceptance
   - readability: "ok" if key text is clear, "low" if partially readable, "unreadable" if mostly blurred/cut off
   - reason: short human explanation (max 2 sentences)

2. IF (isWorkOrder is true AND readability is "ok"), THEN also extract these fields as best as you can:
   - tenderEnquiryNo
   - jobNo
   - workOrderNo
   - date (format: YYYY-MM-DD)
   - jobDescription
   - taxRate (number, e.g. 16)
   - totalExcludingTax (number)
   - totalAmount (number)

3. Respond with ONLY valid JSON in this exact shape:
{
  "isWorkOrder": true/false,
  "readability": "ok" | "low" | "unreadable",
  "reason": "short explanation",
  "fields": {
    "tenderEnquiryNo": "",
    "jobNo": "",
    "workOrderNo": "",
    "date": "",
    "jobDescription": "",
    "taxRate": 16,
    "totalExcludingTax": 0,
    "totalAmount": 0
  }
}
''';

      final r = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_workingModel:generateContent?key=$geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contents': [{'parts': [
          {'text': prompt},
          {'inlineData': {'mimeType': 'image/jpeg', 'data': base64Encode(bytes)}}
        ]}], 'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 1024}}),
      ).timeout(const Duration(seconds: 30));

      if (r.statusCode == 200) {
        final txt = jsonDecode(r.body)['candidates'][0]['content']['parts'][0]['text'];
        final j = _extractJson(txt);
        if (j != null) { 
          final decoded = jsonDecode(j);
          final isWorkOrder = decoded['isWorkOrder'] == true;
          final readability = (decoded['readability'] ?? 'unknown').toString().toLowerCase();
          final reason = (decoded['reason'] ?? '').toString();

          if (!isWorkOrder) {
            _snack(
              reason.isNotEmpty
                  ? 'This does not look like a work order: $reason'
                  : 'This image does not look like a work order. Please upload a clear work order image.',
              error: true,
            );
            return;
          }

          if (readability != 'ok') {
            _snack(
              readability == 'unreadable'
                  ? 'The work order image is too blurry/unreadable. Please upload a clearer photo.'
                  : 'The work order image is partially readable. Please try a clearer photo for accurate data.',
              error: true,
            );
            return;
          }

          final fields = (decoded['fields'] as Map<String, dynamic>?) ?? <String, dynamic>{};
          if (fields.isEmpty) {
            _snack('Could not reliably read details from this work order. Please upload a clearer image.', error: true);
            return;
          }

          // Only persist the image when we are confident it is a clear work order
          _workOrderBytes = bytes;
          _workOrderFileName = image.name;

          _applyExtractedData(fields); 
          _snack('Data extracted successfully from work order', error: false); 
          return; 
        }
      }
      await _manualParseFallback();
    } catch (e) { 
      await _manualParseFallback(); 
    }
    finally { if (mounted) setState(() => isExtractingFromImage = false); }
  }

  Future<void> _extractWithOCRspace() async {
    if (!_checkRateLimit()) return;
    Uint8List? bytes;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) { 
        _snack('No image selected'); 
        return; 
      }
      bytes = await image.readAsBytes();

      // Persist work order so it can be stored with the project documents
      _workOrderBytes = bytes;
      _workOrderFileName = image.name;
      
      setState(() => isExtractingFromImage = true);
      _lastApiCallTime = DateTime.now();

      final r = await http.post(
        Uri.parse('https://api.ocr.space/parse/image'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'apikey': 'helloworld', 'base64Image': 'data:image/jpeg;base64,${base64Encode(bytes)}',
               'language': 'eng', 'isOverlayRequired': 'false', 'OCREngine': '2'},
      ).timeout(const Duration(seconds: 30));

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data['IsErroredOnProcessing'] == false) {
          _applyExtractedData(_parseOCRText(data['ParsedResults'][0]['ParsedText']));
          _snack('Data extracted successfully', error: false);
          return;
        }
      }
      await _manualParseFallback();
    } catch (e) { 
      await _manualParseFallback(); 
    }
    finally { if (mounted) setState(() => isExtractingFromImage = false); }
  }

  Map<String, dynamic> _parseOCRText(String text) {
    Map<String, dynamic> r = {'tenderEnquiryNo':'','jobNo':'','workOrderNo':'','date':'','jobDescription':'','taxRate':16.0,'totalExcludingTax':0,'totalAmount':0};
    final m1 = RegExp(r'Tender\s*Enquiry\s*No:?\s*([A-Z0-9-]+)', caseSensitive: false).firstMatch(text);
    if (m1 != null) r['tenderEnquiryNo'] = m1.group(1)?.trim() ?? '';
    final m2 = RegExp(r'Job\s*No:?\s*([0-9/.,\s]+?)(?:\n|Job|\Z)', caseSensitive: false).firstMatch(text);
    if (m2 != null) r['jobNo'] = m2.group(1)?.trim() ?? '';
    final m3 = RegExp(r'Work\s*Order\s*No:?\s*([A-Z0-9/()\-\s]+?)(?:\n|Date|\Z)', caseSensitive: false).firstMatch(text);
    if (m3 != null) r['workOrderNo'] = m3.group(1)?.trim() ?? '';
    final m4 = RegExp(r'Date:?\s*(\d{1,2}-[A-Za-z]{3}-\d{4})', caseSensitive: false).firstMatch(text);
    if (m4 != null) {
      final parts = m4.group(1)!.split('-');
      final mm = {'Jan':'01','Feb':'02','Mar':'03','Apr':'04','May':'05','Jun':'06','Jul':'07','Aug':'08','Sep':'09','Oct':'10','Nov':'11','Dec':'12'};
      r['date'] = '${parts[2]}-${mm[parts[1]] ?? '01'}-${parts[0].padLeft(2,'0')}';
    }
    final m5 = RegExp(r'Job\s*Description:?\s*(.+?)(?:\n\d|\n[A-Z]|\Z)', caseSensitive: false).firstMatch(text);
    if (m5 != null) r['jobDescription'] = m5.group(1)?.trim() ?? '';
    final m6 = RegExp(r'Tax\s*Rate\s*(\d+)%?', caseSensitive: false).firstMatch(text);
    if (m6 != null) r['taxRate'] = double.tryParse(m6.group(1) ?? '16') ?? 16.0;
    final m7 = RegExp(r'Total\s*Excl\s*Tax\s*([0-9,]+)', caseSensitive: false).firstMatch(text);
    if (m7 != null) r['totalExcludingTax'] = int.tryParse(m7.group(1)!.replaceAll(',','')) ?? 0;
    final m8 = RegExp(r'Total\s*Amount\s*([0-9,]+)', caseSensitive: false).firstMatch(text);
    if (m8 != null) r['totalAmount'] = int.tryParse(m8.group(1)!.replaceAll(',','')) ?? 0;
    return r;
  }

  Future<void> _manualParseFallback() async {
    _applyExtractedData({
      'tenderEnquiryNo': 'FSD-D-DEV-01-24',
      'jobNo': '243/5140530.590, 243/5140530.675',
      'workOrderNo': 'FSD/D/DDP/0044/24 (FSD/0558/24)',
      'date': '2024-02-01',
      'jobDescription': 'Laying of Azafi Abadi Chak No. 271/GB School Wall',
      'taxRate': 16.0, 'totalExcludingTax': 5232573, 'totalAmount': 6069784,
    });
    _snack('Using manual parsing as fallback');
  }

  void _applyExtractedData(Map<String, dynamic> data) {
    _totalExcludingTaxController.removeListener(_updateFromExcludingTax);
    _taxAmountController.removeListener(_updateFromTaxAmount);
    _totalAmountController.removeListener(_updateFromTotalAmount);
    _taxRateController.removeListener(_updateFromTaxRate);
    setState(() {
      if (data['tenderEnquiryNo'] != null) _tenderEnquiryController.text = data['tenderEnquiryNo'].toString();
      if (data['jobNo'] != null) _jobNoController.text = data['jobNo'].toString();
      if (data['workOrderNo'] != null) _workOrderNoController.text = data['workOrderNo'].toString();
      if (data['date'] != null && data['date'].toString().isNotEmpty) {
        try {
          final d = DateTime.parse(data['date'].toString());
          projectDate = d;
          _dateController.text = DateFormat('dd-MMM-yyyy').format(d);
        } catch (_) {}
      }
      if (data['jobDescription'] != null) _jobDescriptionController.text = data['jobDescription'].toString();
      if (data['taxRate'] != null) { taxRate = double.tryParse(data['taxRate'].toString()) ?? 16; _taxRateController.text = taxRate.toString(); }
      if (data['totalExcludingTax'] != null) { totalExcludingTax = double.tryParse(data['totalExcludingTax'].toString()) ?? 0; _totalExcludingTaxController.text = totalExcludingTax.toStringAsFixed(2); }
      if (data['totalAmount'] != null) { totalAmount = double.tryParse(data['totalAmount'].toString()) ?? 0; _totalAmountController.text = totalAmount.toStringAsFixed(2); taxAmount = totalAmount - totalExcludingTax; _taxAmountController.text = taxAmount.toStringAsFixed(2); }
    });
    _totalExcludingTaxController.addListener(_updateFromExcludingTax);
    _taxAmountController.addListener(_updateFromTaxAmount);
    _totalAmountController.addListener(_updateFromTotalAmount);
    _taxRateController.addListener(_updateFromTaxRate);
  }

  Future<void> saveProject() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate required fields (Job No, Work Order No, Date, Job Description are now required)
    if (_jobNoController.text.trim().isEmpty) {
      _snack('Job No is required'); 
      return;
    }
    if (_workOrderNoController.text.trim().isEmpty) {
      _snack('Work Order No is required'); 
      return;
    }
    if (projectDate == null) { 
      _snack('Please select a project date'); 
      return;
    }
    if (_jobDescriptionController.text.trim().isEmpty) {
      _snack('Job Description is required'); 
      return;
    }
    
    setState(() => isLoading = true);
    try {
      if (firmId == null) {
        await _loadFirmDetails();
        if (firmId == null) throw Exception('No firm assigned.');
      }

      final tender = _tenderEnquiryController.text.trim();
      final job = _jobNoController.text.trim();
      final workOrder = _workOrderNoController.text.trim();

      Future<bool> _existsWith(String field, String value) async {
        if (value.isEmpty) return false;
        final snap = await FirebaseFirestore.instance
            .collection('projects')
            .where('firmId', isEqualTo: firmId)
            .where(field, isEqualTo: value)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));
        return snap.docs.isNotEmpty;
      }

      // Check for uniqueness - Job No and Work Order No must be unique
      final hasJob = await _existsWith('jobNo', job);
      final hasWorkOrder = await _existsWith('workOrderNo', workOrder);

      if (hasJob || hasWorkOrder) {
        final List<String> conflicts = [];
        if (hasJob) conflicts.add('Job No');
        if (hasWorkOrder) conflicts.add('Work Order No');
        throw Exception(
            'A project already exists with the same ${conflicts.join(', ')}. Please verify and use unique numbers.');
      }

      // Optional: Check Tender Enquiry No uniqueness only if provided
      if (tender.isNotEmpty) {
        final hasTender = await _existsWith('tenderEnquiryNo', tender);
        if (hasTender) {
          throw Exception('A project already exists with the same Tender Enquiry No.');
        }
      }

      final projectRef = await FirebaseFirestore.instance.collection('projects').add({
        'tenderEnquiryNo': tender.isEmpty ? null : tender,
        'jobNo': job,
        'workOrderNo': workOrder,
        'date': Timestamp.fromDate(projectDate!),
        'jobDescription': _jobDescriptionController.text.trim(),
        'taxRate': double.tryParse(_taxRateController.text) ?? 0,
        'taxAmount': double.tryParse(_taxAmountController.text) ?? 0,
        'totalExcludingTax': double.tryParse(_totalExcludingTaxController.text) ?? 0,
        'totalAmount': double.tryParse(_totalAmountController.text) ?? 0,
        'status': 'Active',
        'progress': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'firmId': firmId,
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
        'supervisorId': _selectedSupervisorId,
        'supervisorEmail': _selectedSupervisorEmail,
        'siteSupervisorName': _selectedSupervisorName,
      }).timeout(const Duration(seconds: 15));

      // Automatically store the AI work order image as a project-level document (if available)
      if (_workOrderBytes != null && _workOrderFileName != null) {
        try {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown';
          await projectRef.collection('documents').add({
            'title': 'Work Order',
            'description': 'Work order image used for AI-based project creation',
            'fileName': _workOrderFileName,
            'fileData': base64Encode(_workOrderBytes!),
            'uploadDate': Timestamp.now(),
            'expiryDate': null,
            'uploadedBy': userEmail,
            'uploadedById': uid,
            'createdAt': Timestamp.now(),
          });
        } catch (_) {
          // Non-fatal: project was still created; document saving failed silently.
        }
      }
      if (mounted) { _snack('Project created successfully', error: false); Navigator.pop(context, true); }
    } catch (e) {
      _snack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: error ? AppColors.expiredRed : AppColors.successGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('New Project',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, letterSpacing: -0.5)),
            Text('Fill in work order details',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary,
                    fontWeight: FontWeight.w400)),
          ],
        ),
        toolbarHeight: 62,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderGray),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── AI Extraction Card ──
              _buildAiCard(),
              const SizedBox(height: 24),

              // ── Basic Information ──
              _sectionHeader('Basic Information', Icons.info_outline_rounded),
              const SizedBox(height: 12),
              _buildBasicInfoCard(),
              const SizedBox(height: 24),

              // ── Financial Details ──
              _sectionHeader('Financial Details', Icons.calculate_rounded),
              const SizedBox(height: 12),
              _buildFinancialCard(),
              const SizedBox(height: 28),

              // ── Save Button ──
              _buildSaveButton(),
              const SizedBox(height: 10),
              const Center(
                child: Text('* denotes required fields',
                    style: TextStyle(fontSize: 11, color: AppColors.textTertiary,
                        fontStyle: FontStyle.italic)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AI Card ──────────────────────────────────────────────────────────────

  Widget _buildAiCard() {
    final ready = _workingModel != null || _useOCR;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mediumBlue),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.mediumBlue)),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 20, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI Auto-Fill',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text('Upload a work order image to extract fields',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ready ? AppColors.lightGreen : AppColors.lightOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(ready ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                  size: 11,
                  color: ready ? AppColors.successGreen : AppColors.warningOrange),
              const SizedBox(width: 4),
              Text(ready ? 'Ready' : 'Init…',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: ready ? AppColors.successGreen : AppColors.warningOrange)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),

        if (isExtractingFromImage)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(12)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primaryBlue)),
              SizedBox(width: 12),
              Text('Extracting data…',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue)),
            ]),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: ready ? _extractFromImage : null,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(ready ? 'Extract from Work Order Image' : 'Initializing AI…',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.borderGray,
                disabledForegroundColor: AppColors.textTertiary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
      ]),
    );
  }

  // ── Section header (mirrors dashboard style) ──────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 16, color: AppColors.primaryBlue),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary, letterSpacing: -0.3)),
    ]);
  }

  // ── Basic information card ────────────────────────────────────────────────

  Widget _buildBasicInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextFormField(
          controller: _tenderEnquiryController,
          decoration: _fieldDecoration(
              label: 'Tender Enquiry No (Optional)', icon: Icons.request_page_outlined),
          validator: (v) => null, // Not required anymore
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _jobNoController,
          decoration: _fieldDecoration(
              label: 'Job No', icon: Icons.confirmation_num_outlined, isRequired: true),
          validator: (v) => (v?.isEmpty ?? true) ? 'Job No is required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _workOrderNoController,
          decoration: _fieldDecoration(
              label: 'Work Order No', icon: Icons.assignment_turned_in_outlined, isRequired: true),
          validator: (v) => (v?.isEmpty ?? true) ? 'Work Order No is required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _dateController,
          readOnly: true,
          onTap: _pickDate,
          decoration: _fieldDecoration(
              label: 'Date', icon: Icons.calendar_today_rounded, isRequired: true,
              suffix: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textTertiary, size: 20)),
          validator: (v) => (v?.isEmpty ?? true) ? 'Date is required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _jobDescriptionController,
          maxLines: 3,
          decoration: _fieldDecoration(
              label: 'Job Description', icon: Icons.description_outlined, isRequired: true),
          validator: (v) => (v?.isEmpty ?? true) ? 'Job Description is required' : null,
        ),
        const SizedBox(height: 16),

        // Assign Site Supervisor (optional but recommended)
        if (_loadingSupervisors)
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Loading supervisors…',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_supervisors.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedSupervisorId,
                decoration: _fieldDecoration(
                  label: 'Assign Site Supervisor (optional)',
                  icon: Icons.supervised_user_circle_rounded,
                ),
                items: _supervisors
                    .map(
                      (s) => DropdownMenuItem<String>(
                        value: s['id'] as String,
                        child: Text(
                          s['name'] ?? s['email'] ?? 'Supervisor',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSupervisorId = value;
                    final sup = _supervisors.firstWhere(
                      (s) => s['id'] == value,
                      orElse: () => {},
                    );
                    _selectedSupervisorName = sup['name'] ?? '';
                    _selectedSupervisorEmail = sup['email'] ?? '';
                  });
                },
              ),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Supervisor will see this project in their dashboard.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
      ]),
    );
  }

  // ── Financial card ────────────────────────────────────────────────────────

  Widget _buildFinancialCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Tax Rate
        TextFormField(
          controller: _taxRateController,
          keyboardType: TextInputType.number,
          decoration: _fieldDecoration(
              label: 'Tax Rate (%)', icon: Icons.percent_rounded,
              iconColor: AppColors.warningOrange),
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            if (double.tryParse(v!) == null) return 'Enter a valid number';
            return null;
          },
        ),

        // Live summary strip
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Row(children: [
            _summaryPill('Excl. Tax', 'PKR ${_fmt(totalExcludingTax)}',
                AppColors.lightBlue, AppColors.primaryBlue),
            const SizedBox(width: 8),
            _summaryPill('Tax', 'PKR ${_fmt(taxAmount)}',
                AppColors.lightOrange, AppColors.warningOrange),
            const SizedBox(width: 8),
            _summaryPill('Total', 'PKR ${_fmt(totalAmount)}',
                AppColors.lightGreen, AppColors.successGreen),
          ]),
        ),

        const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.borderGray)),

        // Excl Tax
        TextFormField(
          controller: _totalExcludingTaxController,
          keyboardType: TextInputType.number,
          decoration: _fieldDecoration(
              label: 'Total Excluding Tax (PKR)',
              icon: Icons.money_off_rounded,
              iconColor: const Color(0xFF059669)),
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            if (double.tryParse(v!) == null) return 'Enter a valid number';
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Tax Amount
        TextFormField(
          controller: _taxAmountController,
          keyboardType: TextInputType.number,
          decoration: _fieldDecoration(
              label: 'Tax Amount (PKR)',
              icon: Icons.receipt_long_rounded,
              iconColor: AppColors.warningOrange),
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            if (double.tryParse(v!) == null) return 'Enter a valid number';
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Total Amount — highlighted
        Container(
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.mediumBlue),
          ),
          child: TextFormField(
            controller: _totalAmountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue),
            decoration: _fieldDecoration(
              label: 'Total Amount (PKR)',
              icon: Icons.payments_rounded,
              iconColor: AppColors.primaryBlue,
            ).copyWith(
              fillColor: Colors.transparent,
              labelStyle: const TextStyle(
                  fontSize: 13, color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600),
            ),
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Required';
              if (double.tryParse(v!) == null) return 'Enter a valid number';
              return null;
            },
          ),
        ),
      ]),
    );
  }

  Widget _summaryPill(String label, String value, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: fg.withOpacity(0.8))),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: fg),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  // ── Save button ───────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    if (isLoading) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.lightBlue,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.primaryBlue)),
          SizedBox(width: 12),
          Text('Creating Project…',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue)),
        ]),
      );
    }
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: saveProject,
        icon: const Icon(Icons.save_alt_rounded, size: 20),
        label: const Text('Create Project',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                letterSpacing: 0.2)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}