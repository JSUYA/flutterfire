// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Tizen implementation of the `firebase_remote_config` plugin.
library firebase_remote_config_tizen;

export 'src/firebase_remote_config_tizen_impl.dart'
    show FirebaseRemoteConfigTizen;
export 'src/remote_config_rest_client.dart'
    show RemoteConfigFetchResponse, RemoteConfigRestClient;
