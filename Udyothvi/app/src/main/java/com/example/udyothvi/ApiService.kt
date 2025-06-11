package com.example.udyothvi

import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.POST

interface ApiService {
    @POST("api/user/upsert")
    suspend fun validateAccount(@Body login: LoginRequest): Response<LoginResponse>

    @POST("api/auth/forgot-password")
    suspend fun forgotPassword(@Body forgotPassword: ForgotPasswordRequest): Response<ForgotPasswordResponse>

    @POST("api/auth/change-password")
    suspend fun changePassword(@Body changePassword: ChangePasswordRequest): Response<ChangePasswordResponse>

    @POST("api/user/upsert-education")
    suspend fun upsertEducation(@Body education: EducationPayload): Response<EducationResponse>

    @POST("api/user/register")
    suspend fun registerAccount(@Body register: RegisterRequest): Response<RegisterResponse>
}