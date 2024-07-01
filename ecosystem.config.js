module.exports = {
    apps: [
      {
        name: "my-app",
        script: "./main",
        args: "-c config/config.toml",
        watch: false, // Change to true if you want PM2 to watch for file changes and restart automatically
        instances: 1, // Set to the number of instances you want to run
        exec_mode: "fork", // Change to 'cluster' if you want to run multiple instances in cluster mode
        env: {
          NODE_ENV: "production",
        },
      },
    ],
  };
  