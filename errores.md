Warning: Flutter support for your project's Kotlin version (1.8.22) will soon be dropped. Please upgrade your Kotlin version to a version of at least 2.1.0 soon.
Alternatively, use the flag "--android-skip-build-dependency-validation" to bypass this check.

Potential fix: Your project's KGP version is typically defined in the plugins block of the `settings.gradle` file (C:\Users\alanG\Documentos\VSC\Flutter\order_qr_mobile\android/settings.gradle), by a plugin with the id of org.jetbrains.kotlin.android. 
If you don't see a plugins block, your project was likely created with an older template version, in which case it is most likely defined in the top-level build.gradle file (C:\Users\alanG\Documentos\VSC\Flutter\order_qr_mobile\android/build.gradle) by the ext.kotlin_version property.

Note: Some input files use or override a deprecated API.
Note: Recompile with -Xlint:deprecation for details.
warning: [options] source value 8 is obsolete and will be removed in a future release
warning: [options] target value 8 is obsolete and will be removed in a future release
warning: [options] To suppress warnings about obsolete options, use -Xlint:-options.
3 warnings
e: file:///C:/Users/alanG/.gradle/caches/8.9/transforms/2062590a286f4236a33df5353423bd45/transformed/jetified-play-services-measurement-impl-22.5.0-api.jar!/META-INF/java.com.google.android.gms.libs.filecompliance.proto_file_access_api_type_kt_proto_lite.kotlin_moduleModule was compiled with an incompatible version of Kotlin. The binary version of its metadata is 2.1.0, expected version is 1.9.0.
e: file:///C:/Users/alanG/.gradle/caches/8.9/transforms/2062590a286f4236a33df5353423bd45/transformed/jetified-play-services-measurement-impl-22.5.0-api.jar!/META-INF/third_party.kotlin.protobuf.src.commonMain.kotlin.com.google.protobuf.kotlin_only_for_use_in_proto_generated_code_its_generator_and_tests.kotlin_moduleModule was compiled with an incompatible version of Kotlin. The binary version of its metadata is 2.1.0, expected version is 1.9.0.
e: file:///C:/Users/alanG/.gradle/caches/8.9/transforms/2062590a286f4236a33df5353423bd45/transformed/jetified-play-services-measurement-impl-22.5.0-api.jar!/META-INF/third_party.kotlin.protobuf.src.commonMain.kotlin.com.google.protobuf.kotlin_shared_runtime.kotlin_moduleModule was compiled with an incompatible version of Kotlin. The binary version of its metadata is 2.1.0, expected version is 1.9.0.
e: file:///C:/Users/alanG/.gradle/caches/8.9/transforms/b30680952feef31712a2476ae055c773/transformed/jetified-play-services-measurement-api-22.5.0-api.jar!/META-INF/java.com.google.android.gmscore.integ.client.measurement_api_measurement_api.kotlin_moduleModule was compiled with an incompatible version of Kotlin. The binary version of its metadata is 2.1.0, expected version is 1.9.0.

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:compileDebugKotlin'.
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.GradleCompilerRunnerWithWorkers$GradleKotlinCompilerWorkAction
   > Compilation error. See log for more details

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 4m 13s
Running Gradle task 'assembleDebug'...                            254.3s

┌─ Flutter Fix ──────────────────────────────────────────────────────────────────────────────────────────┐
│ [!] Your project requires a newer version of the Kotlin Gradle plugin.                                 │
│ Find the latest version on https://kotlinlang.org/docs/releases.html#release-details, then update the  │
│ version number of the plugin with id "org.jetbrains.kotlin.android" in the plugins block of            │
│ C:\Users\alanG\Documentos\VSC\Flutter\order_qr_mobile\android\settings.gradle.                         │
│                                                                                                        │
│ Alternatively (if your project was created before Flutter 3.19), update                                │
│ C:\Users\alanG\Documentos\VSC\Flutter\order_qr_mobile\android\build.gradle                             │
│ ext.kotlin_version = '<latest-version>'                                                                │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
Error: Gradle task assembleDebug failed with exit code 1