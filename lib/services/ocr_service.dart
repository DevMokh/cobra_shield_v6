import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// استخراج نص من صورة (سكرين شوت رسالة) على الجهاز بالكامل، بدون إنترنت.
///
/// ملاحظة مهمة: المكتبة المجانية المستخدمة هنا تدعم قراءة الحروف اللاتينية
/// (إنجليزي، أرقام، روابط) بدقة عالية، لكنها لا تدعم قراءة النص العربي.
/// يعني هتقرأ الأرقام والروابط والكلمات الإنجليزية جوه الصورة كويس، لكن ممكن
/// تفوّت أو تشوّه أي جملة عربية. لذلك النص القابل للتعديل بعد الاستخراج مهم:
/// راجعه وكمّله يدويًا قبل الفحص لو الرسالة عربي.
class OcrService {
  OcrService._();

  static TextRecognizer? _recognizer;

  static TextRecognizer get _r =>
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  static Future<String> extractFromFile(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final result = await _r.processImage(inputImage);
    return result.text.trim();
  }

  static Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
