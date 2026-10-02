import { IsEmail, IsIn, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateUserDto {
  @IsString() name!: string;
  @IsEmail() email!: string;
  @IsString() @MinLength(8) password!: string;
  @IsIn(['ADMIN','MANAGER','SALES','VIEWER']) role!: 'ADMIN'|'MANAGER'|'SALES'|'VIEWER';
}
export class UpdateUserDto {
  @IsOptional() @IsString() name?: string;
  @IsOptional() @IsIn(['ADMIN','MANAGER','SALES','VIEWER']) role?: 'ADMIN'|'MANAGER'|'SALES'|'VIEWER';
  @IsOptional() active?: boolean;
}
