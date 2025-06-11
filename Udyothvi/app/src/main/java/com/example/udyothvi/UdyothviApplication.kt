package com.example.udyothvi

import android.app.Application
import android.content.Context
import android.util.Log

class UdyothviApplication : Application() {
    companion object {
        private lateinit var context: Context

        fun getContext(): Context {
            if (!::context.isInitialized) {
                throw IllegalStateException("UdyothviApplication context not initialized")
            }
            return context
        }
    }

    override fun onCreate() {
        super.onCreate()
        context = applicationContext
        Log.d("UdyothviApplication", "Context initialized: $context")
    }
}