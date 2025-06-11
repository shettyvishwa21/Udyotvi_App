package com.example.udyothvi

data class UpsertUserResult(
    val ResultType: Int = 0,
    val ResultMessage: String? = null,
    val UserId: Long = 0
)