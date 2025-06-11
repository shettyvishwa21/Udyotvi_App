package com.example.udyothvi.model

import android.net.Uri

data class UserProfile(
    val fullName: String,
    val title: String,
    val company: String,
    val education: String,
    val location: String,
    val about: String? = null,
    val skills: List<String> = emptyList(),
    val experiences: List<Experience> = emptyList(),
    val website: String? = null,
    val linkedIn: String? = null,
    val github: String? = null,
    val twitter: String? = null,
    val languages: List<String> = emptyList(),
    val interests: List<String> = emptyList(),
    val profileImage: Uri? = null,
    val coverImage: Uri? = null
)

data class Experience(
    val title: String,
    val company: String,
    val startDate: String,
    val endDate: String,
    val description: String
) 