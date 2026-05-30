import '../../domain/entities/bank_account.dart';
import '../../domain/repositories/bank_account_repository.dart';
import '../datasources/payspin_api_client.dart';
import '../mappers/api_mappers.dart';

class BankAccountRepositoryImpl implements BankAccountRepository {
  BankAccountRepositoryImpl(this._api);

  final PayspinApiClient _api;

  @override
  Future<List<BankAccount>> listAccounts() async {
    final list = await _api.listBankAccounts();
    return list.map((e) => mapBankAccount(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<BankAccount> addAccount({
    required String iban,
    required String accountHolder,
    String? bankName,
  }) async {
    final json = await _api.addBankAccount(iban: iban, accountHolder: accountHolder, bankName: bankName);
    return mapBankAccount(json);
  }
}
