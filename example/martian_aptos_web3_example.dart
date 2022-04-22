import 'package:martiandao_aptos_web3/martiandao_aptos_web3.dart';
void main() async {
  var wal = WalletClient();

  print("Creating wallet");  
  final det = await wal.createWallet();
  
  print("Wallet Created $det");  
  print("Current balance ${await wal.getBalance(det['address'])}");

  print("Airdropping 5000 coins");
  await wal.airdrop(det['code'], 5000);
  
  print("Updated balance ${await wal.getBalance(det['address'])}");
}
