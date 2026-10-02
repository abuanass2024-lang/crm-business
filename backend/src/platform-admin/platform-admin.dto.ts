import { IsIn, IsString, MinLength } from 'class-validator';
export class CompanyStatusDto { @IsIn(['ACTIVE','SUSPENDED']) status!: 'ACTIVE'|'SUSPENDED'; }
export class AssignPlanDto { @IsString() @MinLength(2) planCode!: string; @IsIn(['TRIAL','ACTIVE','PAST_DUE','SUSPENDED','CANCELLED']) status?: 'TRIAL'|'ACTIVE'|'PAST_DUE'|'SUSPENDED'|'CANCELLED'; }
