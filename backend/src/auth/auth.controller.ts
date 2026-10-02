import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { LoginDto, RefreshDto, RegisterDto } from './auth.dto';
import { JwtGuard } from './jwt.guard';
@Controller('auth') export class AuthController { constructor(private service:AuthService){} @Post('register-company') register(@Body()d:RegisterDto){return this.service.register(d)} @Post('login') login(@Body()d:LoginDto){return this.service.login(d)} @Post('refresh') refresh(@Body()d:RefreshDto){return this.service.refresh(d.refreshToken)} @Post('logout') logout(@Body()d:RefreshDto){return this.service.logout(d.refreshToken)} @Get('me') @UseGuards(JwtGuard) me(@Req()r:any){return this.service.me(r.user.userId)} }
