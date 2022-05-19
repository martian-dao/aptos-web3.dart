# Martian aptos-web3 dart Docs

# Introduction

Web3 library for Aptos

# Supported functions

1. createWallet: create a new wallet
2. importWallet: import an existing wallet
3. airdrop: airdrop test coins into an account
4. getBalance: get the balance of an account
5. transfer: transfer coins from one account to another
6. getSentEvents: get Sent events of an account
7. getReceivedEvents: get Received events of an account
8. createNFTCollection: create an NFT collection
9. createNFT: create an NFT
10. offerNFT: offer an NFT to a receiver
11. claimNFT: claim an NFT offered by a sender
12. cancelNFTOffer: cancel an outgoing NFT offer
<!-- 13. rotateAuthKey: rotate authentication key -->

## Functions and their args, return values and description

| Name | Argument: [name: type] | Returns | Description |
| --- | --- | --- | --- |
| createWallet | None | "code": string  "address key": string | This method is used to create new wallet. It returns “code” which is a secret phrase and “address key” which is public address of the wallet |
| importWallet | code: string | "address key": string | This method is used to import wallet from mnemonic/secret phrase. It returns “address key” which is public address of the wallet |
| airdrop | code: string  amount: number | None | This method is used to add coins in the wallet.  |
| getBalance | address: string | balance: Integer | This method is used to get available balance of any address. It returns integer |
| transfer | code: string  recipient_address: string  amount: number | None | This method is used to transfer fund from one account to another. It returns Nothing |
| getSentEvents | address: string | [Click Here](https://fullnode.devnet.aptoslabs.com/accounts/e1acaa6eadbde51a0070327f095a1253deb1bbe919369b971621156fa18bd770/events/0x1::TestCoin::TransferEvents/sent_events)| This method is used to fetch sent events done by the wallet. Please hit the url given in the returns field to see what it return |
| getReceivedEvents | address: string |[Click Here](https://fullnode.devnet.aptoslabs.com/accounts/e1acaa6eadbde51a0070327f095a1253deb1bbe919369b971621156fa18bd770/events/0x1::TestCoin::TransferEvents/received_events) | This method is used to fetch received events to the wallet. Please hit the url given in the returns field to see what it return |
| createNFTCollection | code: string name: string description: string uri: string | hash: string | This method is used to create collection inside the wallet/account. It returns submission hash |
| createNFT | code: string collection_name: string name: string description: string supply: number uri: string | hash: string | This method is used to create nft inside collection. It returns submission hash |
| offerNFT | code: string receiver_address: string  creator_address: string collection_name: string token_name: string amount: number | hash: string | This method is used to offer nft to another address. |
| claimNFT | code: string sender_address: string creator_address: string collection_name: string token_name: string | hash: string | This method is used to claim nft offered |
<!-- | rotateAuthKey | code: string new_auth_key: string | hash: string | This method is used to rotate the authentication key. The new private/ public key pair used to derive the new auth key will be used to sign the account after this function call completes | -->

# Usage Example Wallet

```
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

  print("\nAirdropping 12000 coins to alice");
  await wal.airdrop(det['code'], 12000);
  print("Updated balance alice ${await wal.getBalance(det['address'])}");

  print("\nAirdropping 12000 coins to bob");
  await wal.airdrop(alice['code'], 12000);
  print("Updated balance bob ${await wal.getBalance(alice['address'])}");

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

  print("\n\nNFT Examples");
  const description = "Alice's simple collection";
  const collectionName = "AliceCollection";
  const tokenName = "AliceToken";
  const uri = "https://aptos.dev";
  const img = "https://aptos.dev/img/nyan.jpeg";

  print("Creating Collection: \nDescription -> $description \nName -> $collectionName \nURI -> $uri");
  print(await wal.createNFTCollection(det['code'], collectionName, description, uri));

  print("Creating NFT Token: image url -> $img, TokenName -> $tokenName");
  print(await wal.createNFT(det['code'], collectionName, tokenName, description, 1, img));

  print("\n\nTransfer NFT");
  await wal.offerNFT(det['code'], alice['address'], det['address'], collectionName, tokenName, 1);
  await wal.claimNFT(alice['code'], det['address'], det['address'], collectionName, tokenName);
  print("Transfer Completed");
}
```

# To install dependencies and run example
```
dart pub install
dart run example/martian_aptos_web3_example.dart
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/martian-dao/aptos-web3.dart/issues