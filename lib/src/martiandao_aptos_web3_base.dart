import 'dart:convert';
import 'package:hex/hex.dart';
import 'package:pinenacl/ed25519.dart';
import 'package:sha3/sha3.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:http/http.dart' as http;
import 'dart:async';

const testUrl = "https://fullnode.devnet.aptoslabs.com";
const faucetUrl = "https://faucet.devnet.aptoslabs.com";

// Timer setTimeout(callback, [int duration = 1000]) {
//   return Timer(Duration(milliseconds: duration), callback);
// }

class Account {
  // KeyPair signingKey = Signature.keyPair();
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
    var k = SHA3(256, KECCAK_PADDING, 256);
    k.update(signingKey.publicKey);
    var hash = k.digest();
    return HEX.encode(hash);
  }

  String pubKey() {
    return HEX.encode(signingKey.publicKey);
  }
}

class FaucetClient {
  var uri = faucetUrl;
  RestClient restClient = RestClient();
  FaucetClient({endpoint = faucetUrl}) {
    uri = endpoint;
  }
  fundAccount(String authKey, int amount) async {
    var url = "$uri/mint?amount=$amount&auth_key=$authKey";
    final response = await http.post(Uri.parse(url));
    if (response.statusCode != 200) {
      assert(response.statusCode == 200, response.body);
    }

    final tnxHashes = jsonDecode(response.body);
    for (final tnxHash in tnxHashes) {
      await restClient.waitForTransaction(tnxHash);
    }
  }
}

class RestClient {
  var uri = testUrl;
  final hex = HexCoder.instance;
  RestClient({endpoint = testUrl}) {
    uri = endpoint;
  }

  account(String accountAddress) async {
    var url = "$uri/accounts/$accountAddress";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      assert(response.statusCode == 200, response.body);
    }

    jsonDecode(response.body);
  }

  accountResources(String accountAddress) async {
    var url = "$uri/accounts/$accountAddress/resources";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      assert(response.statusCode == 200, response.body);
    }

    return jsonDecode(response.body);
  }

  accountSentEvents(String accountAddress) async {
    var url =
        "$uri/accounts/$accountAddress/events/0x1::TestCoin::TransferEvents/sent_events";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      assert(response.statusCode == 200, response.body);
    }

    jsonDecode(response.body);
  }

  accountReceivedEvents(String accountAddress) async {
    var url =
        "$uri/accounts/$accountAddress/events/0x1::TestCoin::TransferEvents/received_events";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      assert(response.statusCode == 200, response.body);
    }

    jsonDecode(response.body);
  }

  generateTransaction(String sender, Map payload) async {
    var acc = await account(sender);
    var seqNum = acc["sequence_number"];
    return {
      "sender": "0x$sender",
      "sequence_number": seqNum.toString(),
      "max_gas_amount": "4000",
      "gas_unit_price": "1",
      "gas_currency_code": "XUS",
      "expiration_timestamp_secs":
          (DateTime.now().millisecondsSinceEpoch / 1000 + 600)
              .toInt()
              .toString(),
      "payload": payload,
    };
  }

  signTransaction(Account accountFrom, Map txnRequest) async {
    var url = "$uri/transactions/signing_message";
    final response = await http.post(Uri.parse(url), body: txnRequest);
    if (response.statusCode != 200) {
      assert(response.statusCode == 200, response.body);
    }
    var result = jsonDecode(response.body);
    var toSign = hex.decode(result['message'].substring(2));
    final signature = accountFrom.signingKey.sign(toSign);
    final signatureHex = hex.encode(signature).substring(0, 128);
    txnRequest["signature"] = {
      "type": "ed25519_signature",
      "public_key": '0x$accountFrom.pubKey()',
      "signature": '0x$signatureHex',
    };
    return txnRequest;
  }

  submitTransaction(Account accountFrom, Map txnRequest) async {
    var url = "$uri/transactions";
    final response = await http.post(Uri.parse(url), body: txnRequest);
    if (response.statusCode != 202) {
      assert(response.statusCode == 202, '$response.body-$txnRequest');
    }
    return jsonDecode(response.body);
  }

  transactionPending(String txnHash) async {
    var url = "$uri/transactions/$txnHash";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 404) {
      return true;
    }
    if (response.statusCode != 200) {
      assert(response.statusCode == 200, response.body);
    }
    return jsonDecode(response.body)['type'] == "pending_transaction";
  }

  waitForTransaction(String txnHash) async {
    var count = 0;
    while (await transactionPending(txnHash)) {
      assert(count < 10);
      await Future.delayed(Duration(seconds: 1));
      print(count);
      count += 1;
      if (count >= 10) {
        throw Exception('Waiting for transaction $txnHash timed out!');
      }
    }
  }

  accountBalance(String accountAddress) async {
    final resources = await accountResources(accountAddress);
    for (final resource in resources) {
      if (resource["type"] == "0x1::TestCoin::Balance") {
        return int.parse(resource["data"]["coin"]["value"]);
      }
    }
    return null;
  }

  transfer(Account accountFrom, String recipient, int amount) async {
    final payload = {
      "type": "script_function_payload",
      "function": "0x1::TestCoin::transfer",
      "type_arguments": [],
      "arguments": [
        '0x$recipient',
        amount.toString(),
      ]
    };
    final txnRequest =
        await generateTransaction(accountFrom.address(), payload);
    final signedTxn = await signTransaction(accountFrom, txnRequest);
    final res = await submitTransaction(accountFrom, signedTxn);
    return res["hash"].toString();
  }
}

class WalletClient {
  FaucetClient faucetClient = FaucetClient();
  RestClient restClient = RestClient();
  getAccountFromMnemonic(code) {
    if (!bip39.validateMnemonic(code)) {
      throw Exception("Invalid mnemonic");
    }
    var seed = bip39.mnemonicToSeed(code);
    var account = Account.fromSeed(seed.sublist(0, 32));

    return account;
  }

  Future<Map> createWallet() async {
    var code = bip39.generateMnemonic();
    Account account = getAccountFromMnemonic(code);
    await faucetClient.fundAccount(account.authKey(), 10);
    return {"code": code, "address": account.address()};
  }

  Future<Map> importWallet(String code) async {
    Account account = getAccountFromMnemonic(code);
    faucetClient.fundAccount(account.authKey(), 10);
    return {"address": account.address()};
  }

  Future<int> getBalance(String address) async {
    var balance = await restClient.accountBalance(address);
    return balance;
  }

  airdrop(String code, int amount) async {
    Account account = getAccountFromMnemonic(code);
    await faucetClient.fundAccount(account.authKey(), amount);
  }
}
