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


  print("\Importing wallet test");  
  final temp =  await wal.importWallet(alice['code']);
  print(temp);

  print("\nAirdropping 12000 coins to alice");
  await wal.airdrop(det['code'], 12000);
  print("Updated balance alice ${await wal.getBalance(det['address'])}");

  print("\nAirdropping 12000 coins to bob");
  await wal.airdrop(alice['code'], 12000);
  print("Updated balance bob ${await wal.getBalance(alice['address'])}");

  print("\nTransferring 1000 from ${det['address']} (bob) -> ${alice['address']} (alice)");
  print("=========================================================================");
  await wal.transfer(det['code'], alice['address'], 1000);

  print("Wallet balance of alice account -> ${alice['address']}");
  print("=========================================================================");
  print("${await wal.getBalance(alice['address'])}");

  print("Wallet balance of bob account -> ${det['address']}");
  print("=========================================================================");
  print("${await wal.getBalance(det['address'])}");

  print("\nGetting Sent Events of account -> ${det['address']}");
  print("=========================================================================");
  print(await wal.getSentEvents(det['address']));

  print("\nGetting Received Events of account -> ${alice['address']}");
  print("=========================================================================");
  print(await wal.getReceivedEvents(alice['address']));

  print("\n\nNFT Examples");
  const description = "Alice's simple collection";
  const collectionName = "AliceCollection";
  const tokenName = "AliceToken";
  const uri = "https://aptos.dev";
  const img = "https://aptos.dev/img/nyan.jpeg";

  print("\nCreating Collection: \nDescription -> $description \nName -> $collectionName \nURI -> $uri");
  print(await wal.createNFTCollection(det['code'], collectionName, description, uri));

  print("\nCreating NFT Token: image url -> $img, TokenName -> $tokenName");
  print(await wal.createNFT(det['code'], collectionName, tokenName, description, 1, img));

  print("\n\nGetting all NFTs");
  print(await wal.getTokens(det['address']));

  print("\n\nGetting single NFT");
  print(await wal.getToken(det['address'], collectionName, tokenName));

  print("\n\nTransfer NFT");
  await wal.offerNFT(det['code'], alice['address'], det['address'], collectionName, tokenName, 1);
  await wal.claimNFT(alice['code'], det['address'], det['address'], collectionName, tokenName);
  print("Transfer Completed");
}
