import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ListInstitutionsUseCase } from '../../../application/use-cases/open-banking/list-institutions.use-case';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';

@Controller('open-banking')
@UseGuards(JwtAuthGuard)
export class OpenBankingController {
  constructor(private readonly listInstitutions: ListInstitutionsUseCase) {}

  @Get('institutions')
  institutions(@Query('country') country?: string) {
    return this.listInstitutions.execute(country);
  }
}
