
import java.lang.reflect.Method;
class OutputMethod {
    public static void main(String[] args) {
        //System.out.println("classpath : " + System.getProperty("Java.class.path"));
        for (String arg : args) {
            OutputMethod.outputMethod(arg);
        }
    }


    public static StringBuilder getMethod(Class<?> clazz) throws Exception {
        String className = clazz.getName();
        //Method[] methods = clazz.getDeclaredMethods();
        Method[] methods = clazz.getMethods();
        StringBuilder builder = new StringBuilder();
        for (Method method : methods) {
            String methodName = method.getName();
            String returntype = method.getReturnType().getName();
            builder.append(className).append("#");
            builder.append(returntype).append (" ");
            builder.append(methodName).append("(");
            Class<?>[] parameterTypes = method.getParameterTypes();
            for (int i = 0; i < parameterTypes.length; i++) {
                Class<?> parameterType = parameterTypes[i];
                builder.append(parameterType.getName());
                if (i + 1 < parameterTypes.length) {
                    builder.append(", ");
                }
            }
            builder.append(")");
            builder.append(System.getProperty("line.separator"));
        }
        Class<?> superclazz = clazz.getSuperclass();
        if (superclazz != null) {
            builder.append(getMethod(superclazz));
        }
        return builder;
    }
    private static void outputMethod(String classpath) {
        Class<?> clazz = null;
        try{
            clazz = Class.forName(classpath);
            System.out.println(getMethod(clazz).toString());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
