import { IsEmail, IsString, MinLength, MaxLength, IsOptional, Matches } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class RegisterDto {
  @ApiProperty() @IsEmail() email: string;
  @ApiProperty() @IsString() @MinLength(2) @MaxLength(50) name: string;
  @ApiProperty() @IsString() @MinLength(3) @MaxLength(30)
  @Matches(/^[a-z0-9_]+$/, { message: 'Username: lowercase letters, numbers, underscores only' })
  username: string;
  @ApiProperty() @IsString() @MinLength(8) @MaxLength(100) password: string;
}

export class LoginDto {
  @ApiProperty() @IsEmail() email: string;
  @ApiProperty() @IsString() password: string;
}

export class RefreshTokenDto {
  @ApiProperty() @IsString() refreshToken: string;
}

export class ForgotPasswordDto {
  @ApiProperty() @IsEmail() email: string;
}

export class ResetPasswordDto {
  @ApiProperty() @IsString() token: string;
  @ApiProperty() @IsString() @MinLength(8) newPassword: string;
}

export class ChangePasswordDto {
  @ApiProperty() @IsString() currentPassword: string;
  @ApiProperty() @IsString() @MinLength(8) newPassword: string;
}

export class VerifyOtpDto {
  @ApiProperty() @IsString() otp: string;
  @ApiProperty() @IsEmail() email: string;
}
