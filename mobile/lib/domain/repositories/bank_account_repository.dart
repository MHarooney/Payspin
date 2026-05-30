import '../entities/bank_account.dart';

abstract class BankAccountRepository {
  Future<List<BankAccount>> listAccounts();
  Future<BankAccount> addAccount({required String iban, required String accountHolder, String? bankName});
}
