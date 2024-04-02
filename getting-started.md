# StakeWise Operator DAppNode Package Guide

Welcome to the StakeWise Operator Package for DAppNode! This comprehensive guide assists you in setting up and running a StakeWise operator node on your DAppNode device effortlessly.

**Become a StakeWise Operator in Simple Steps:**

1. **Create Your Vault:** Begin by creating your vault on the StakeWise platform. Visit [StakeWise Operator Setup](https://app.stakewise.io/operate?networkId=holesky) to get started.

2. **Install the StakeWise Package:** Navigate to your DAppNode device's dashboard and install the StakeWise Operator package.

3. **Configure Your Package:** Input your vault's contract address and specify the number of validators you wish to operate in the StakeWise package settings on your DAppNode or leave the fields empty if you are going to import an existing operator by uploading a backup.

4. **Download and Handle the Backup Carefully:**

   - Download your operator's backup data from the [StakeWise Backup tab](http://my.dappnode/packages/my/stakewise-operator-holesky.dnp.dappnode.eth/backup) and **store it securely**.

5. **Upload the Deposit Data:**

   - Uncompress the backup file.
   - Locate the `deposit_data.json` file within the backup at `/data/stakewise/<vault_address>/deposit_data.json`.
   - Upload this file to your vault via the [StakeWise application](https://app.stakewise.io/operate?networkId=holesky) by navigating to Vault Settings > Upload deposit data.

6. **Secure Your Mnemonic:**

   - Find your mnemonic inside the backup at `/data/mnemonic/mnemonic.txt`.
   - Ensure this mnemonic is stored securely and privately.

7. **Remove the Mnemonic Volume:**
   - For enhanced security, remove the mnemonic volume associated with your StakeWise Operator package. This can be done at [StakeWise Operator Info](http://my.dappnode/packages/my/stakewise-operator-holesky.dnp.dappnode.eth/info).
   - **Remove only** the volume labeled as **"mnemonic"**.

**Congratulations!** You are now set to operate your StakeWise vault on Dappnode.
