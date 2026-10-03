import {
  IsBoolean,
  IsEnum,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export enum AutomationTriggerDto {
  CUSTOMER_CREATED = 'CUSTOMER_CREATED',
  OPPORTUNITY_CREATED = 'OPPORTUNITY_CREATED',
  OPPORTUNITY_STAGE_CHANGED = 'OPPORTUNITY_STAGE_CHANGED',
  TASK_CREATED = 'TASK_CREATED',
  TASK_DUE_SOON = 'TASK_DUE_SOON',
  TASK_OVERDUE = 'TASK_OVERDUE',
  OPPORTUNITY_WON = 'OPPORTUNITY_WON',
  OPPORTUNITY_LOST = 'OPPORTUNITY_LOST',
}

export enum AutomationActionDto {
  CREATE_TASK = 'CREATE_TASK',
  CREATE_NOTIFICATION = 'CREATE_NOTIFICATION',
  CHANGE_CUSTOMER_STATUS = 'CHANGE_CUSTOMER_STATUS',
  LOG_ACTIVITY = 'LOG_ACTIVITY',
}

export class CreateAutomationRuleDto {
  @IsString()
  @MaxLength(150)
  name!: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsEnum(AutomationTriggerDto)
  trigger!: AutomationTriggerDto;

  @IsOptional()
  @IsObject()
  condition?: Record<string, any>;

  @IsEnum(AutomationActionDto)
  action!: AutomationActionDto;

  @IsOptional()
  @IsObject()
  actionData?: Record<string, any>;

  @IsOptional()
  @IsBoolean()
  enabled?: boolean;
}

export class UpdateAutomationRuleDto
  extends CreateAutomationRuleDto {}