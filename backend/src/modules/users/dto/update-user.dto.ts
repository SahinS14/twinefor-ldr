import { IsString, IsOptional, IsEnum, IsArray, MaxLength } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { LoveLanguage } from '../../../database/entities/user.entity';

export class UpdateUserDto {
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(50) name?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(200) bio?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() birthday?: string;
  @ApiPropertyOptional() @IsOptional() @IsEnum(LoveLanguage) loveLanguage?: LoveLanguage;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(100) moodStatus?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() themePreference?: string;
  @ApiPropertyOptional() @IsOptional() @IsArray() interests?: string[];
  @ApiPropertyOptional() @IsOptional() @IsString() avatarUrl?: string;
}
