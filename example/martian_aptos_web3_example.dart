import 'package:martiandao_aptos_web3/martiandao_aptos_web3.dart';
// import 'package:martiandao_aptos_web3/src/account_client.dart';

void main() async {
  var wal = WalletClient();

  print("Creating wallet for Alice");  
  final alice = await wal.createWallet();
  
  print("Wallet Created $alice");  
  print("Current balance ${await wal.getBalance(alice['accounts'][0]['address'])}");

  print("\nCreating wallet for bob");  
  final bob = await wal.createWallet();
  
  print("Wallet Created $bob");  
  print("Current balance ${await wal.getBalance(bob['accounts'][0]['address'])}");


  dynamic aliceAccount = wal.getAccountFromMetaData(alice['code'], alice['accounts'][0]);
  dynamic bobAccount = wal.getAccountFromMetaData(bob['code'], bob['accounts'][0]);

  var aliceAddress = alice['accounts'][0]['address'];
  var bobAddress = bob['accounts'][0]['address'];


  print("\nAirdropping 12000 coins to alice");
  await wal.airdrop(aliceAccount, 12000);
  print("Updated balance alice ${await wal.getBalance(aliceAddress)}");

  print("\nAirdropping 12000 coins to bob");
  await wal.airdrop(bobAccount, 12000);
  print("Updated balance bob ${await wal.getBalance(bobAddress)}");

  print("\nTransferring 1000 from $aliceAddress (alice) -> $bobAddress (bob)");
  print("=========================================================================");
  await wal.transfer(aliceAccount, bobAddress, 1000);

  print("Wallet balance of alice account -> $aliceAddress");
  print("=========================================================================");
  print("${await wal.getBalance(aliceAddress)}");

  print("Wallet balance of bob account -> $bobAddress");
  print("=========================================================================");
  print("${await wal.getBalance(bobAddress)}");

  print("\nGetting Sent Events of account (alice) -> $aliceAddress");
  print("=========================================================================");
  print(await wal.getSentEvents(aliceAddress));

  print("\nGetting Received Events of account (bob) -> $bobAddress");
  print("=========================================================================");
  print(await wal.getReceivedEvents(bobAddress));

  print("\Importing wallet test");  
  final temp =  await wal.importWallet(alice['code']);
  print(temp);

  print("\n\nNFT Examples");
  const description = "Alice's simple collection";
  const collectionName = "AliceCollection";
  const tokenName = "AliceToken";
  const uri = "https://aptos.dev";
  const img = "https://aptos.dev/img/nyan.jpeg";

  print("\nCreating Collection: \nDescription -> $description \nName -> $collectionName \nURI -> $uri");
  print(await wal.createNFTCollection(aliceAccount, collectionName, description, uri));

  print("\nCreating NFT Token: image url -> $img, TokenName -> $tokenName");
  print(await wal.createNFT(aliceAccount, collectionName, tokenName, description, 1, img));

  print("\n\nGetting all NFTs");
  print(await wal.getTokens(aliceAddress));

  print("\n\nGetting single NFT");
  print(await wal.getToken(aliceAddress, collectionName, tokenName));

  print("\n\nTransfer NFT");
  await wal.offerNFT(aliceAccount, bobAddress, aliceAddress, collectionName, tokenName, 1);
  await wal.claimNFT(aliceAccount,aliceAddress, aliceAddress, collectionName, tokenName);
  print("Transfer Completed");

  print("\nTesting cache");
  dynamic cacheAliceAccount = wal.getAccountFromMetaData(alice['code'], alice['accounts'][0]);
  print("\nAirdropping 12000 coins to alice using cached account");
  await wal.airdrop(cacheAliceAccount, 12000);
  print("Updated balance alice ${await wal.getBalance(aliceAddress)}");


  print("\nRotating auth key of alice");
  print("=========================================================================");
  print(await wal.rotateAuthKey(alice['code'], alice['accounts'][0]));

  print("Getting JSON payload");
  print("=========================================================================");
  // String recipientAddress, String amount, String contractAddress
  // NOTE: Here contract address is not correct it is just for testing
  print(await wal.getJsonPayload(aliceAccount, "1000", aliceAccount));

  print("\nTransferring 1000 from $aliceAddress (alice) -> $bobAddress (bob) SHOULD THROW EXCEPTION: INVALID_AUTH_KEY");
  print("=========================================================================");
  await wal.transfer(aliceAccount, bobAddress, 1000);
}
