import { IsEmail, IsString, MinLength } from 'class-validator';
export class RegisterDto { @IsString() @MinLength(2) companyName:string; @IsString() @MinLength(2) ownerName:string; @IsEmail() email:string; @IsString() @MinLength(8) password:string; }
export class LoginDto { @IsEmail() email:string; @IsString() password:string; }
export class RefreshDto { @IsString() @MinLength(20) refreshToken:string; }
