import { IsBoolean, IsEmail, IsIn, IsOptional, IsString, MinLength } from 'class-validator';

const ROLES = [
  'GENERAL_MANAGER',
  'REGIONAL_MANAGER',
  'BRANCH_MANAGER',
  'HALL_MANAGER',
  'SUPERVISOR',
  'CUSTOMER_SERVICE',
  'OWNER','ADMIN','MANAGER','SALES','VIEWER',
] as const;

export class CreateUserDto {
  @IsString() name!: string;
  @IsEmail() email!: string;
  @IsString() @MinLength(8) password!: string;
  @IsOptional() @IsString() employeeId?: string;
  @IsOptional() @IsString() branch?: string;
  @IsIn(ROLES as any) role!: string;
}

export class UpdateUserDto {
  @IsOptional() @IsString() name?: string;
  @IsOptional() @IsString() employeeId?: string;
  @IsOptional() @IsString() branch?: string;
  @IsOptional() @IsIn(ROLES as any) role?: string;
  @IsOptional() @IsBoolean() active?: boolean;
}

export class TransferUserDto {
  @IsString() branch!: string;
}
