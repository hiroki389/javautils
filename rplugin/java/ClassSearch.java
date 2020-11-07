
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.file.FileVisitResult;
import java.nio.file.FileVisitor;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

class ClassSearch {
    public static void main(String[] args) throws Exception {
        String[] classpathlist = null;
        if (args.length == 0 ) {
            String separator = System.getProperty("path.separator");
            String jarPath = System.getProperty("java.class.path");
            classpathlist = jarPath.split(separator);
        } else {
            classpathlist = args;
        }
        for (String arg : classpathlist) {
            //System, out. pr i ntln(arg);
            //ZipUtils. decode(new File("C:\\Program Files\\Java\\jdk1.8.0_161\\jre\\lib\\rt.jar"));
            File file = new File(arg);
            List<String> list = new ArrayList<>();
            if (file.exists() && file.toPath().getFileName().toString().endsWith(".jar")) {
                list = ClassSearch.decode(file);
            } else if (file.isDirectory()) {
                list = ClassSearch.walkFileTree(file.toPath());
            }
            for (String str : list) {
                System.out.println("" + str.replaceAll("[\\\\\\/]",".").replaceAll("\\.class$|\\.java$",""));
            }
        }
    }
    public static List<String> decode(File file) throws Exception {
        final List<String> list = new ArrayList<>();
        ZipInputStream zis = new ZipInputStream(new FileInputStream(file));
        Pattern p = Pattern.compile("\\.class$");
        for (ZipEntry entry = zis.getNextEntry(); entry != null; entry = zis.getNextEntry()){
            if (entry.isDirectory()) continue;
            if (!entry.getName().contains("$") && p.matcher(entry.getName()).find()) {
                list.add(entry.getName());
            }
        }
        zis.close();
        return list;
    }
    public static List<String> walkFileTree(Path dir) throws Exception {
        final List<String> list = new ArrayList<>();
        final Path adir = dir;
        Files.walkFileTree(dir, new FileVisitor<Path>() {
            @Override
            public FileVisitResult preVisitDirectory (Path dir, BasicFileAttributes attrs) throws IOException {
                return FileVisitResult.CONTINUE;
            }
            @Override
            public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
                if (file.getFileName().toString().endsWith(".java") || file.getFileName().toString().endsWith(".class")) {
                    list.add(file.toAbsolutePath().toString().replace(adir.toAbsolutePath().toString() + "\\",""));
                }
                return FileVisitResult.CONTINUE;
            }
            @Override
            public FileVisitResult visitFileFailed(Path file, IOException exc) throws IOException {
                return FileVisitResult.CONTINUE;
            }
            @Override
            public FileVisitResult postVisitDirectory(Path dir, IOException exc) throws IOException {
                return FileVisitResult.CONTINUE;
            }
        });
        return list;
    }
}
