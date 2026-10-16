# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["DockerDemoApi.csproj", "."]
RUN dotnet restore "DockerDemoApi.csproj"

COPY . .
RUN dotnet publish "DockerDemoApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "DockerDemoApi.dll"]
