import { IsDateString, IsEnum, IsInt, IsNumber, IsOptional, IsString, IsUUID, Max, Min } from 'class-validator';
import { OpportunityStage } from '@prisma/client';
export class CreateOpportunityDto {
  @IsString() customerId!: string;
  @IsString() title!: string;
  @IsNumber() value!: number;
  @IsOptional() @IsString() currency?: string;
  @IsOptional() @IsEnum(OpportunityStage) stage?: OpportunityStage;
  @IsOptional() @IsInt() @Min(0) @Max(100) probability?: number;
  @IsOptional() @IsDateString() expectedCloseDate?: string;
  @IsOptional() @IsUUID() assignedTo?: string;
}
export class UpdateOpportunityDto {
  @IsOptional() @IsUUID() customerId?: string;
  @IsOptional() @IsString() title?: string;
  @IsOptional() @IsNumber() value?: number;
  @IsOptional() @IsString() currency?: string;
  @IsOptional() @IsEnum(OpportunityStage) stage?: OpportunityStage;
  @IsOptional() @IsInt() @Min(0) @Max(100) probability?: number;
  @IsOptional() @IsDateString() expectedCloseDate?: string;
  @IsOptional() @IsUUID() assignedTo?: string;
}
