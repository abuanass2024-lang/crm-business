import { IsDateString, IsEnum, IsOptional, IsString } from 'class-validator';
export enum TaskStatusDto { TODO='TODO', IN_PROGRESS='IN_PROGRESS', COMPLETED='COMPLETED', CANCELLED='CANCELLED' }
export enum TaskPriorityDto { LOW='LOW', MEDIUM='MEDIUM', HIGH='HIGH', URGENT='URGENT' }
export class CreateTaskDto {
 @IsString() title!: string; @IsOptional() @IsString() description?: string;
 @IsOptional() @IsString() customerId?: string; @IsOptional() @IsString() opportunityId?: string;
 @IsOptional() @IsString() assignedTo?: string; @IsOptional() @IsDateString() dueDate?: string;
 @IsOptional() @IsEnum(TaskPriorityDto) priority?: TaskPriorityDto;
}
export class UpdateTaskDto extends CreateTaskDto {
 @IsOptional() @IsEnum(TaskStatusDto) status?: TaskStatusDto;
}
