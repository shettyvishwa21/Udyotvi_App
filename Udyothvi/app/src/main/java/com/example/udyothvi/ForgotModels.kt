package com.example.udyothvi

import com.google.gson.annotations.SerializedName

data class ForgotPasswordRequest(
    val email: String
)

data class ForgotPasswordResponse(
    @SerializedName("resultType") val resultType: Int,
    @SerializedName("resultMessage") val resultMessage: String,
    @SerializedName("resultData") val resultData: ForgotPasswordResultData?
)

data class ForgotPasswordResultData(
    @SerializedName("tempPassword") val tempPassword: String?,
    @SerializedName("userId") val userId: String?
)