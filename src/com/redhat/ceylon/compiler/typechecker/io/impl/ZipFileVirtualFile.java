package com.redhat.ceylon.compiler.typechecker.io.impl;

import com.redhat.ceylon.compiler.typechecker.io.ClosableVirtualFile;
import com.redhat.ceylon.compiler.typechecker.io.VirtualFile;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.LinkedList;
import java.util.List;
import java.util.SortedSet;
import java.util.TreeSet;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

/**
 * @author Emmanuel Bernard <emmanuel@hibernate.org>
 */
public class ZipFileVirtualFile implements ClosableVirtualFile {

    protected final ZipFile zipFile;
    private final String name;
    private final List<VirtualFile> children;
    private final boolean closable;

    public ZipFileVirtualFile(File file) throws IOException {
        this( new ZipFile(file), true );
    }

    public ZipFileVirtualFile(ZipFile zipFile) {
        this( zipFile, false );
    }

    private ZipFileVirtualFile(ZipFile zipFile, boolean closable) {
        this.closable = closable;
        this.zipFile = zipFile;
        final String path = zipFile.getName();
        final int lastIndex = path.lastIndexOf(File.separator);
        this.name = lastIndex == -1 ? path : path.substring(lastIndex+1);
        final Enumeration<? extends ZipEntry> entries = zipFile.entries();
        SortedSet<String> entryNames = new TreeSet<String>();
        while ( entries.hasMoreElements() ) {
            entryNames.add( entries.nextElement().getName() );
        }
        List<VirtualFile> directChildren = new ArrayList<VirtualFile>();
        LinkedList<ZipFolderVirtualFile> directoryStack = new LinkedList<ZipFolderVirtualFile>();
        for ( String entryName : entryNames ) {
            final ZipEntry entry = zipFile.getEntry(entryName);
            if ( entry.isDirectory() ) {
                /*
                entries are ordered,
                if an entry is a child of the previous entry, add it as child
                if an entry is not a child of the previous entry, move up till we find its parent
                 */
                final ZipFolderVirtualFile folder = new ZipFolderVirtualFile(entry, path);
                addToParentfolder(directChildren, directoryStack, entryName, folder);
                directoryStack.addLast(folder);
            }
            else {
                ZipEntryVirtualFile file = new ZipEntryVirtualFile(entry, zipFile);
                addToParentfolder(directChildren, directoryStack, entryName, file);
            }
        }
        children = directChildren;
    }

    private void addToParentfolder(List<VirtualFile> directChildren, LinkedList<ZipFolderVirtualFile> directoryStack, String entryName, VirtualFile file) {
        ZipFolderVirtualFile up = directoryStack.peekLast();
        while ( !isChildOf(entryName, up) ) {
            directoryStack.pollLast();
            up = directoryStack.peekLast();
        }
        if (up == null) {
            directChildren.add(file);
        }
        else {
            up.addChild(file);
        }
    }

    private boolean isChildOf(String entryName, ZipFolderVirtualFile lastFolder) {
        if (lastFolder == null) {
            return true;
        }
        return entryName.startsWith( lastFolder.getEntryName() );
    }

    @Override
    public boolean isFolder() {
        return true;
    }

    @Override
    public String getName() {
        return zipFile.getName();
    }

    @Override
    public String getPath() {
        return zipFile.getName();
    }

    @Override
    public InputStream getInputStream() {
        throw new IllegalStateException("Cannot call getInputStream() on a directory: " + getPath() );
    }

    @Override
    public List<VirtualFile> getChildren() {
        return children;
    }

    @Override
    public String toString() {
        final StringBuilder sb = new StringBuilder();
        sb.append("ZipFileVirtualFile");
        sb.append("{name='").append(name).append('\'');
        sb.append('}');
        return sb.toString();
    }

    @Override
    public void close() {
        if (closable) {
            try {
                zipFile.close();
            }
            catch (IOException e) {
                throw new RuntimeException(e);
            }
        }
    }
}
