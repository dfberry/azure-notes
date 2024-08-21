import { promises as fs } from 'fs';
import * as path from 'path';

const { readdir, stat, readFile } = fs;

async function findPackageJsonFiles(dir: string): Promise<string[]> {
    let results: string[] = [];
    const list = await readdir(dir);
    for (const file of list) {
        const filePath = path.join(dir, file);
        const fileStat = await stat(filePath);
        if (fileStat && fileStat.isDirectory()) {
            results = results.concat(await findPackageJsonFiles(filePath));
        } else if (file === 'package.json') {
            results.push(filePath);
        }
    }
    return results;
}

async function checkDependency(filePath: string): Promise<boolean> {
    const data = await readFile(filePath, 'utf8');
    const json = JSON.parse(data);
    return json.dependencies && json.dependencies['@azure/core-auth'] !== undefined;
}
async function checkReadme(filePath: string): Promise<string> {
    const readmePath = path.join(path.dirname(filePath), 'README.md');
    try {
        const data = await readFile(readmePath, 'utf8');
        const hasTokenCredential = data.includes('TokenCredential');
        const hasDefaultAzureCredential = data.includes('DefaultAzureCredential');
        if (hasTokenCredential && hasDefaultAzureCredential) {
            return 'Both';
        } else if (hasTokenCredential) {
            return 'TokenCredential';
        } else if (hasDefaultAzureCredential) {
            return 'DefaultAzureCredential';
        } else {
            return 'None';
        }
    } catch (error) {
        return 'README.md not found';
    }
}
async function findDependencyInPackages(dir: string): Promise<void> {
    const packageJsonFiles = await findPackageJsonFiles(dir);
    const results = await Promise.all(packageJsonFiles.map(async (file) => {
        const hasDependency = await checkDependency(file);
        let readmeStatus = 'N/A';
        if (hasDependency) {
            readmeStatus = await checkReadme(file);
        }
        return { file, found: hasDependency, readmeStatus };
    }));

    // Filter out paths that contain 'arm'
    const filteredResults = results.filter(result => 
        !result.file.toLowerCase().includes('arm') && 
        !result.file.toLowerCase().includes('samples') && 
        !result.file.toLowerCase().includes('test')
    );

    // Sort results to have true first and false after
    filteredResults.sort((a, b) => Number(b.found) - Number(a.found));

    // Create Markdown table
    let markdownTable = '| File | Dependency found | README Status |\n| --- | --- | --- |\n';
    filteredResults.forEach(result => {
        // Remove the '../azure-sdk-for-js/sdk/' prefix
        const trimmedFile = result.file.replace('../azure-sdk-for-js/sdk/', '');
        markdownTable += `| ${trimmedFile} | ${result.found} | ${result.readmeStatus} |\n`;
    });
    
    // Write the Markdown table to DAC.md
    await fs.writeFile('DAC.md', markdownTable);
}

// Example usage
const directoryPath = '../azure-sdk-for-js/sdk';
findDependencyInPackages(directoryPath).catch(console.error);