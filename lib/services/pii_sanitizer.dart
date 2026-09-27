/// On-device PII sanitizer for Indian financial documents.
/// Runs BEFORE any text leaves the device to protect sensitive data.
class PiiSanitizer {
  PiiSanitizer._();

  static String sanitize(String text) {
    var s = text;

    // Indian PAN: ABCDE1234F
    s = s.replaceAll(RegExp(r'[A-Z]{5}[0-9]{4}[A-Z]'), '[PAN_REDACTED]');

    // Aadhaar: 1234 5678 9012
    s = s.replaceAll(RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\b'), '[AADHAAR_REDACTED]');

    // Account numbers: 9-18 digit sequences
    s = s.replaceAll(RegExp(r'\b\d{9,18}\b'), '[ACCT_REDACTED]');

    // Indian mobile: +91 or 0 followed by 10 digits
    s = s.replaceAll(RegExp(r'(?:\+91|0)?[6-9]\d{9}'), '[PHONE_REDACTED]');

    // Email addresses
    s = s.replaceAll(RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+'), '[EMAIL_REDACTED]');

    // IFSC codes: 4 letters + 0 + 6 alphanumeric
    s = s.replaceAll(RegExp(r'[A-Z]{4}0[A-Z0-9]{6}'), '[IFSC_REDACTED]');

    return s;
  }
}
