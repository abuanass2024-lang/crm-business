import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { PermissionGuard, RequirePermission } from '../auth/permission.guard';
import { CreateTaskDto, UpdateTaskDto } from './tasks.dto';
import { CreateTaskCommentDto } from './task-comment.dto';
import { TasksService } from './tasks.service';

@Controller('tasks')
@UseGuards(JwtGuard, PermissionGuard)
export class TasksController {
  constructor(private service: TasksService) {}

  @Get()
  @RequirePermission('tasks.read')
  list(@Req() r: any, @Query('status') s?: string) {
    return this.service.list(r.user.companyId, s);
  }

  @Get(':id')
  @RequirePermission('tasks.read')
  get(@Req() r: any, @Param('id') id: string) {
    return this.service.get(r.user.companyId, id);
  }

  @Post()
  @RequirePermission('tasks.create')
  create(@Req() r: any, @Body() d: CreateTaskDto) {
    return this.service.create(r.user.companyId, r.user.userId, d);
  }

  @Patch(':id')
  @RequirePermission('tasks.update')
  update(@Req() r: any, @Param('id') id: string, @Body() d: UpdateTaskDto) {
    return this.service.update(r.user.companyId, id, d);
  }

  @Delete(':id')
  @RequirePermission('tasks.delete')
  remove(@Req() r: any, @Param('id') id: string) {
    return this.service.remove(r.user.companyId, id);
  }

  // ═══ Task Comments (Chat) ═══

  @Get('comments/summary')
  @RequirePermission('tasks.read')
  commentsSummary(@Req() r: any) {
    return this.service.commentsSummary(r.user.companyId, r.user.userId);
  }

  @Get(':id/comments')
  @RequirePermission('tasks.read')
  listComments(@Req() r: any, @Param('id') id: string) {
    return this.service.listComments(r.user.companyId, id);
  }

  @Post(':id/comments')
  @RequirePermission('tasks.update')
  addComment(
    @Req() r: any,
    @Param('id') id: string,
    @Body() d: CreateTaskCommentDto,
  ) {
    return this.service.addComment(r.user.companyId, r.user.userId, id, d);
  }

  @Delete(':id/comments/:cid')
  @RequirePermission('tasks.update')
  deleteComment(
    @Req() r: any,
    @Param('id') id: string,
    @Param('cid') cid: string,
  ) {
    return this.service.deleteComment(
      r.user.companyId,
      r.user.userId,
      r.user.role,
      id,
      cid,
    );
  }
}
