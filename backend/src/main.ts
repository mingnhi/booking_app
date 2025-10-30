import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import * as dotenv from 'dotenv';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  dotenv.config();
  app.enableCors({
    origin: '*', // Thay bằng domain frontend của bạn
    methods: 'GET,POST,PUT,DELETE', // Các phương thức HTTP được phép
    allowedHeaders: 'Content-Type, Authorization', // Các header được phép
  });
  const config = new DocumentBuilder()
    .setTitle('Booking API')
    .setDescription('API documentation for Booking backend')
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);
  await app.listen(process.env.PORT ?? 3000, '0.0.0.0');
}
bootstrap();
