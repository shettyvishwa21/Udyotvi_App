package com.example.udyothvi

import com.google.gson.annotations.SerializedName

data class EducationPayload(
    @SerializedName("userId") val userId: Long,
    @SerializedName("educationData") val educationData: List<EducationRequest>
)

data class EducationRequest(
    @SerializedName("education_id") val educationId: Int,
    @SerializedName("education_level") val educationLevel: String,
    @SerializedName("organisation_name") val organisationName: String,
    @SerializedName("currently_pursuing") val currentlyPursuing: Boolean,
    @SerializedName("start_date") val startDate: String, // ISO 8601, e.g., "2023-06-01T00:00:00Z"
    @SerializedName("end_date") val endDate: String? // Nullable, null if currentlyPursuing
)

data class EducationResponse(
    @SerializedName("resultType") val resultType: Int,
    @SerializedName("resultMessage") val resultMessage: String?,
    @SerializedName("resultData") val resultData: UpsertEducationResult?
)

data class UpsertEducationResult(
    @SerializedName("resultType") val resultType: Int,
    @SerializedName("resultMessage") val resultMessage: String?,
    @SerializedName("userId") val userId: Long
)