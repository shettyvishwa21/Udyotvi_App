package com.example.udyothvi

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import com.example.udyothvi.model.UserProfile
import com.example.udyothvi.model.Experience

class ProfileViewModel : ViewModel() {
    private val _userProfile = MutableStateFlow<UserProfile?>(null)
    val userProfile: StateFlow<UserProfile?> = _userProfile.asStateFlow()

    fun updateProfile(
        fullName: String,
        title: String,
        company: String,
        education: String,
        location: String,
        about: String? = null,
        skills: List<String> = emptyList(),
        experiences: List<Experience> = emptyList(),
        website: String? = null,
        linkedIn: String? = null,
        github: String? = null,
        twitter: String? = null,
        languages: List<String> = emptyList(),
        interests: List<String> = emptyList(),
        profileImage: Uri? = null,
        coverImage: Uri? = null
    ) {
        viewModelScope.launch {
            _userProfile.value = UserProfile(
                fullName = fullName,
                title = title,
                company = company,
                education = education,
                location = location,
                about = about,
                skills = skills,
                experiences = experiences,
                website = website,
                linkedIn = linkedIn,
                github = github,
                twitter = twitter,
                languages = languages,
                interests = interests,
                profileImage = profileImage,
                coverImage = coverImage
            )
        }
    }
} 