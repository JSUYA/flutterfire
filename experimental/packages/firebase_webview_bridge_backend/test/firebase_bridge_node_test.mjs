import { createFirebaseTizenBridge } from '../web/firebase_tizen_bridge_core.mjs';

const fakeSdk = {
  initializeApp(config) {
    return { ...config };
  },
  getAuth(app) {
    return { app };
  },
  async signInWithEmailAndPassword(_auth, email, _password) {
    return {
      user: {
        uid: 'user-123',
        email,
        refreshToken: 'bridge-refresh',
        async getIdTokenResult() {
          return { token: 'bridge-token' };
        },
      },
    };
  },
  getFunctions(app, region) {
    return { app, region };
  },
  httpsCallable(functions, name) {
    return async (data) => ({
      data: {
        message: 'ok',
        echo: data,
        functionName: name,
        region: functions.region,
      },
    });
  },
};

const bridge = createFirebaseTizenBridge(fakeSdk);
await bridge.execute('initialize', {
  apiKey: 'test-api-key',
  projectId: 'test-project',
});

const session = await bridge.execute('signInWithEmailAndPassword', {
  email: 'user@example.com',
  password: 'secret',
});
if (session.idToken !== 'bridge-token') {
  throw new Error(`Unexpected token: ${session.idToken}`);
}

const result = await bridge.execute('callFunction', {
  name: 'echo',
  region: 'us-central1',
  data: { value: 42 },
});
if (result.result.echo.value !== 42) {
  throw new Error(`Unexpected callable payload: ${JSON.stringify(result)}`);
}

console.log('ok');
