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

async function findDependencyInPackages(dir: string): Promise<void> {
    const packageJsonFiles = await findPackageJsonFiles(dir);
    const results = await Promise.all(packageJsonFiles.map(async (file) => {
        const hasDependency = await checkDependency(file);
        return { file, found: hasDependency };
    }));

    // Sort results to have true first and false after
    results.sort((a, b) => Number(b.found) - Number(a.found));

    // Print results with a space between true and false
    results.forEach(result => {
        console.log(`File: ${result.file}, Dependency found: ${result.found}`);
    });
}

// Example usage
const directoryPath = '../azure-sdk-for-js/sdk';
findDependencyInPackages(directoryPath).catch(console.error);