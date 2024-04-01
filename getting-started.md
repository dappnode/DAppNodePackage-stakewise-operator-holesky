# StakeWise Operator DAppNode Package Guide

Welcome to the StakeWise Operator Package for DAppNode! This comprehensive guide assists you in setting up and running a StakeWise operator node on your DAppNode device effortlessly.

**Become a StakeWise Operator in Simple Steps:**

1. **Create Your Vault:** Begin by creating your vault on the StakeWise platform. Visit [StakeWise Operator Setup](https://app.stakewise.io/operate?networkId=holesky) to get started.

2. **Install the StakeWise Package:** Navigate to your DAppNode device's dashboard and install the StakeWise Operator package.

3. **Configure Your Package:** Input your vault's contract address and specify the number of validators you wish to operate in the StakeWise package settings on your DAppNode.

4. **Download and Handle the Backup Carefully:**

   - Download your operator's backup data from the link: [StakeWise Operator Backup](http://my.dappnode/packages/my/stakewise-operator-holesky.dnp.dappnode.eth/backup).
   - **Important:** Securing this backup is crucial for your operation's integrity and security.

5. **Upload the Deposit Data:**

   - Unzip the backup file.
   - Locate the `deposit_data.json` file within the backup at `/data/stakewise/<vault_address>/deposit_data.json`.
   - Upload this file to your vault via the StakeWise application by navigating to your vault's settings and selecting the option to upload deposit data.

6. **Secure Your Mnemonic:**

   - Find your mnemonic inside the backup at `/data/mnemonic/mnemonic.txt`.
   - Ensure this mnemonic is stored securely and privately. After securing the mnemonic, delete the `mnemonic.txt` file from the backup to prevent unauthorized access.

7. **Remove the Mnemonic Volume:**
   - For enhanced security, remove the mnemonic volume associated with your StakeWise Operator package. This can be done from the package details page on your DAppNode at [StakeWise Operator Info](http://my.dappnode/packages/my/stakewise-operator-holesky.dnp.dappnode.eth/info).
   - **Note:** Be cautious to remove only the volume labeled as "mnemonic."

**Congratulations!** You are now set to operate your StakeWise vault on DAppNode. By following these steps, you ensure a smooth setup process, contributing to the StakeWise ecosystem's strength and security.

Should you encounter any issues or have questions during the setup process, the StakeWise and DAppNode communities are available to assist you. Happy staking!
