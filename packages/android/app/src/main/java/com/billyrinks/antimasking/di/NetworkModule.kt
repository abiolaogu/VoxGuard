package com.billyrinks.antimasking.di

import com.apollographql.apollo3.ApolloClient
import com.apollographql.apollo3.cache.normalized.api.MemoryCacheFactory
import com.apollographql.apollo3.cache.normalized.normalizedCache
import com.apollographql.apollo3.network.okHttpClient
import com.apollographql.apollo3.network.ws.GraphQLWsProtocol
import com.apollographql.apollo3.network.ws.WebSocketNetworkTransport
import com.billyrinks.antimasking.BuildConfig
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import java.util.concurrent.TimeUnit
import javax.inject.Singleton

/**
 * Network module providing Apollo GraphQL client and OkHttp
 */
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        val loggingInterceptor = HttpLoggingInterceptor().apply {
            level = if (BuildConfig.DEBUG) {
                HttpLoggingInterceptor.Level.BODY
            } else {
                HttpLoggingInterceptor.Level.NONE
            }
        }

        return OkHttpClient.Builder()
            .addInterceptor { chain ->
                val request = chain.request().newBuilder()
                    .addHeader("Content-Type", "application/json")
                    .apply {
                        val secret = BuildConfig.HASURA_ADMIN_SECRET
                        if (secret.isNotEmpty()) {
                            addHeader("x-hasura-admin-secret", secret)
                        }
                    }
                    .build()
                chain.proceed(request)
            }
            .addInterceptor(loggingInterceptor)
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build()
    }

    @Provides
    @Singleton
    fun provideApolloClient(
        okHttpClient: OkHttpClient
    ): ApolloClient {
        // Memory cache for normalized caching
        val memoryCacheFactory = MemoryCacheFactory(maxSizeBytes = 10 * 1024 * 1024)

        return ApolloClient.Builder()
            .serverUrl(BuildConfig.HASURA_ENDPOINT)
            .okHttpClient(okHttpClient)
            // WebSocket for subscriptions
            .subscriptionNetworkTransport(
                WebSocketNetworkTransport.Builder()
                    .serverUrl(BuildConfig.HASURA_WS_ENDPOINT)
                    .protocol(GraphQLWsProtocol.Factory())
                    .build()
            )
            // Normalized cache
            .normalizedCache(memoryCacheFactory)
            .build()
    }
}
