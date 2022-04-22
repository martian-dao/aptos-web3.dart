import 'package:martiandao_aptos_web3/martiandao_aptos_web3.dart';
void main() async {
  var wal = WalletClient();

  print("Creating wallet for Bob");  
  final det = await wal.createWallet();
  
  print("Wallet Created $det");  
  print("Current balance ${await wal.getBalance(det['address'])}");

  print("\nCreating wallet for Alice");  
  final alice = await wal.createWallet();
  
  print("Wallet Created $alice");  
  print("Current balance ${await wal.getBalance(alice['address'])}");

  print("\nAirdropping 5000 coins");
  await wal.airdrop(det['code'], 5000);
  
  print("Updated balance ${await wal.getBalance(det['address'])}");

  print("\nTransferring 1000 from ${det['address']} -> ${alice['address']}");
  print("=========================================================================");
  await wal.transfer(det['code'], alice['address'], 1000);

  print("Wallet balance of account -> ${alice['address']}");
  print("=========================================================================");
  print("${await wal.getBalance(alice['address'])}");

  print("\nGetting Sent Events of account -> ${det['address']}");
  print("=========================================================================");
  print(await wal.getSentEvents(det['address']));

  print("\nGetting Received Events of account -> ${alice['address']}");
  print("=========================================================================");
  print(await wal.getReceivedEvents(alice['address']));
}
