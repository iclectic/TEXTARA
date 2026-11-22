import 'package:flutter_test/flutter_test.dart';
import 'package:textara/data/services/encrypted_backup.dart';

void main() {
  test('EncryptedBackup round-trips plaintext with passphrase', () {
    const plain = '{"version":"1.0.0","books":[]}';
    final sealed = EncryptedBackup.seal(plain, 'correct-horse');
    expect(sealed.contains(EncryptedBackup.magic), isTrue);
    expect(EncryptedBackup.open(sealed, 'correct-horse'), plain);
  });

  test('EncryptedBackup rejects short passphrases', () {
    expect(
      () => EncryptedBackup.seal('{}', 'short'),
      throwsA(isA<ArgumentError>()),
    );
  });
}
