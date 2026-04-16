export function createFirebaseTizenBridge(firebaseSdk) {
  let app = null;
  let auth = null;
  let currentUser = null;

  function requireApp() {
    if (!app) {
      throw new Error('Bridge has not been initialized.');
    }
    return app;
  }

  async function initialize(args) {
    app = firebaseSdk.initializeApp({
      apiKey: args.apiKey,
      projectId: args.projectId,
    });
    auth = firebaseSdk.getAuth(app);
    if (args.authBaseUrl) {
      auth.__authBaseUrl = args.authBaseUrl;
    }
    if (args.functionsBaseUrl) {
      app.__functionsBaseUrl = args.functionsBaseUrl;
    }
    return { initialized: true };
  }

  async function signInWithEmailAndPassword(args) {
    requireApp();
    const credential = await firebaseSdk.signInWithEmailAndPassword(
      auth,
      args.email,
      args.password,
    );
    currentUser = credential.user;
    const tokenResult = await currentUser.getIdTokenResult();
    return {
      idToken: tokenResult.token,
      refreshToken: currentUser.refreshToken || '',
      localId: currentUser.uid,
      email: currentUser.email || null,
    };
  }

  async function callFunction(args) {
    const activeApp = requireApp();
    const functions = firebaseSdk.getFunctions(activeApp, args.region);
    const callable = firebaseSdk.httpsCallable(functions, args.name);
    const result = await callable(args.data);
    return { result: result.data };
  }

  async function dispose() {
    app = null;
    auth = null;
    currentUser = null;
    return { disposed: true };
  }

  return {
    async execute(command, args = {}) {
      switch (command) {
        case 'initialize':
          return initialize(args);
        case 'signInWithEmailAndPassword':
          return signInWithEmailAndPassword(args);
        case 'callFunction':
          return callFunction(args);
        case 'dispose':
          return dispose();
        default:
          throw new Error(`Unsupported command: ${command}`);
      }
    },
  };
}
