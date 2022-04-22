import 'dart:convert';
import 'package:hex/hex.dart';
import 'package:pinenacl/ed25519.dart';
import 'package:sha3/sha3.dart';

class Account {
  var signingKey = SigningKey.generate();

  Account();
  Account.fromSeed(Uint8List seed) {
    // signingKey = Signature.keyPair_fromSeed(seed);
    signingKey = SigningKey(seed: seed);
  }

  String address() {
    return authKey();
  }

  String authKey() {
    var k = SHA3(256, SHA3_PADDING, 256);
    k.update(signingKey.publicKey);
    k.update(utf8.encode("\x00"));
    var hash = k.digest();
    return HEX.encode(hash);
  }

  String pubKey() {
    return HEX.encode(signingKey.publicKey);
  }
}
