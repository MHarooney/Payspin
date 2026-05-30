import '../entities/bank_account.dart';
import '../entities/institution.dart';

abstract class BankAccountRepository {
  Future<List<BankAccount>> listAccounts();
  Future<BankAccount> addAccount({required String iban, required String accountHolder, String? bankName});
  Future<List<Institution>> listInstitutions({String? country});
  Future<BankConnectionStart> startConnect({String? institutionId});
  Future<BankAccount> completeConnect({
    required String connectionId,
    required String consentToken,
    String? expectedIban,
  });
}
