import { IsOptional, IsString } from 'class-validator';
export class CreateActivityDto { @IsString() type!:string; @IsString() description!:string; @IsOptional() @IsString() customerId?:string; @IsOptional() @IsString() opportunityId?:string; }
