import 'package:bip39/bip39.dart' as bip39;
import 'dart:async';
import 'account_client.dart';
import 'faucet_client.dart';
import 'rest_client.dart';


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

  Future<void> airdrop(String code, int amount) async {
    Account account = getAccountFromMnemonic(code);
    await faucetClient.fundAccount(account.authKey(), amount);
  }

  Future<void> transfer(String code, String recipientAddress, int amount) async {
    Account account = getAccountFromMnemonic(code);
    await restClient.transfer(account, recipientAddress, amount);
  }

  getSentEvents(String address) async {
    return await restClient.accountSentEvents(address);
  }

  getReceivedEvents(String address) async {
    return await restClient.accountReceivedEvents(address);
  }
}
