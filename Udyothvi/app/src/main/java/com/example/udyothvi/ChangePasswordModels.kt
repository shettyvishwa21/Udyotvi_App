package com.example.udyothvi

import com.google.gson.annotations.SerializedName

data class ChangePasswordRequest(
    @SerializedName("userId") val userId: Long,
    @SerializedName("currentPassword") val currentPassword: String,
    @SerializedName("newPassword") val newPassword: String,
    @SerializedName("requireAllDevices") val requireAllDevices: Boolean
)

data class ChangePasswordResponse(
    @SerializedName("resultType") val resultType: Int,
    @SerializedName("resultMessage") val resultMessage: String
)