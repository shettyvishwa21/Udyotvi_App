package com.example.udyothvi

import com.google.gson.annotations.SerializedName

data class LoginRequest(
    @SerializedName("Id") val id: Long = 0,
    @SerializedName("Email") val email: String,
    @SerializedName("Password") val password: String,
    @SerializedName("IsSsoUser") val isSsoUser: Boolean = false
)

data class LoginResponse(
    @SerializedName("resultMessage") val resultMessage: String?,
    @SerializedName("resultType") val resultType: Int,
    @SerializedName("resultData") val resultData: LoginResultData?
)

data class LoginResultData(
    @SerializedName("userId") private val _userId: String?,
    @SerializedName("email") val email: String?,
    @SerializedName("resultMessage") val resultMessage: String?,
    @SerializedName("resultType") val resultType: Int
) {
    val userId: Long?
        get() = _userId?.toLongOrNull()
}

data class ResultData(
    @SerializedName("account_id") val accountID: Long,
    @SerializedName("account_type") val accountType: String,
    @SerializedName("token") val token: String
)